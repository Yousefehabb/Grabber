import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { after, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  Timestamp,
} from 'firebase/firestore';

const rules = await readFile(
  new URL('../../firestore.rules', import.meta.url),
  'utf8',
);
const testEnv = await initializeTestEnvironment({
  projectId: 'demo-grabber-rules',
  firestore: { rules },
});

after(async () => {
  await testEnv.cleanup();
});

function profile(overrides = {}) {
  return {
    fullName: 'Ada Lovelace',
    email: 'ada@example.test',
    mobileNumber: '+12025550123',
    gender: 'female',
    createdAt: serverTimestamp(),
    ...overrides,
  };
}

function address(overrides = {}) {
  return {
    city: 'London',
    district: 'Central',
    streetName: 'Example Street',
    buildingNumber: '12A',
    updatedAt: serverTimestamp(),
    ...overrides,
  };
}

function legacyAddress() {
  return {
    city: 'London',
    district: 'Central',
    streetName: 'Example Street',
    buildingNumber: '12A',
  };
}

function userDoc(db, uid) {
  return doc(db, 'users', uid);
}

function addressDoc(db, uid) {
  return doc(db, 'users', uid, 'addresses', 'primary');
}

function favoriteDoc(db, uid, productId) {
  return doc(db, 'users', uid, 'favorites', productId);
}

function favorite(productId = 'banana', overrides = {}) {
  return {
    productId,
    addedAt: serverTimestamp(),
    ...overrides,
  };
}

async function seed(uid, documentPath, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), documentPath), data);
  });
}

test('owner creates and reads a profile using a server timestamp; gender may be omitted', async () => {
  const db = testEnv.authenticatedContext('profile-owner').firestore();
  const data = profile();
  delete data.gender;

  await assertSucceeds(setDoc(userDoc(db, 'profile-owner'), data));
  const snapshot = await assertSucceeds(getDoc(userDoc(db, 'profile-owner')));

  assert.equal(snapshot.exists(), true);
  assert.equal(snapshot.data().gender, undefined);
  assert.ok(snapshot.data().createdAt instanceof Timestamp);
});

test('owner may write either gender value', async () => {
  const maleDb = testEnv.authenticatedContext('male-owner').firestore();
  const femaleDb = testEnv.authenticatedContext('female-owner').firestore();

  await assertSucceeds(setDoc(userDoc(maleDb, 'male-owner'), profile({ gender: 'male' })));
  await assertSucceeds(
    setDoc(
      userDoc(femaleDb, 'female-owner'),
      profile({ gender: 'female', fullName: 'Grace Hopper' }),
    ),
  );
});

test('profile updates preserve the original createdAt timestamp', async () => {
  const db = testEnv.authenticatedContext('retry-owner').firestore();
  const ref = userDoc(db, 'retry-owner');

  await assertSucceeds(setDoc(ref, profile()));
  await assertFails(setDoc(ref, profile({ fullName: 'Ada Byron' })));
  const existing = await getDoc(ref);
  await assertSucceeds(
    setDoc(
      ref,
      profile({
        fullName: 'Ada Byron',
        gender: 'male',
        createdAt: existing.data().createdAt,
      }),
    ),
  );

  const snapshot = await assertSucceeds(getDoc(ref));
  assert.equal(snapshot.data().fullName, 'Ada Byron');
  assert.equal(snapshot.data().gender, 'male');
});

test('owner may read their existing primary address', async () => {
  await seed(
    'address-reader',
    'users/address-reader/addresses/primary',
    legacyAddress(),
  );
  const db = testEnv.authenticatedContext('address-reader').firestore();

  const snapshot = await assertSucceeds(
    getDoc(addressDoc(db, 'address-reader')),
  );

  assert.equal(snapshot.exists(), true);
  assert.equal(snapshot.data().updatedAt, undefined);
});

test('owner may create and update the primary address using set', async () => {
  const db = testEnv.authenticatedContext('address-writer').firestore();
  const ref = addressDoc(db, 'address-writer');

  await assertSucceeds(setDoc(ref, address()));
  await assertSucceeds(
    setDoc(ref, address({ city: 'Oxford', buildingNumber: '7' })),
  );

  const snapshot = await assertSucceeds(getDoc(ref));
  assert.equal(snapshot.data().city, 'Oxford');
  assert.equal(snapshot.data().buildingNumber, '7');
  assert.ok(snapshot.data().updatedAt instanceof Timestamp);
});

test('owner may create, read, list, and delete their Favorites', async () => {
  const db = testEnv.authenticatedContext('favorite-owner').firestore();
  const ref = favoriteDoc(db, 'favorite-owner', 'banana');

  await assertSucceeds(setDoc(ref, favorite()));
  const snapshot = await assertSucceeds(getDoc(ref));
  const favorites = await assertSucceeds(
    getDocs(collection(db, 'users', 'favorite-owner', 'favorites')),
  );

  assert.equal(snapshot.data().productId, 'banana');
  assert.ok(snapshot.data().addedAt instanceof Timestamp);
  assert.equal(favorites.size, 1);
  await assertFails(setDoc(ref, favorite('banana')));
  await assertSucceeds(deleteDoc(ref));
});

test('Favorites require authentication and cannot be accessed across users', async () => {
  await seed(
    'favorite-owner',
    'users/favorite-owner/favorites/banana',
    { productId: 'banana', addedAt: new Date() },
  );
  const anonymousDb = testEnv.unauthenticatedContext().firestore();
  const otherUserDb = testEnv.authenticatedContext('different-user').firestore();

  await assertFails(getDoc(favoriteDoc(anonymousDb, 'favorite-owner', 'banana')));
  await assertFails(
    getDocs(collection(anonymousDb, 'users', 'favorite-owner', 'favorites')),
  );
  await assertFails(
    setDoc(favoriteDoc(anonymousDb, 'anonymous', 'banana'), favorite()),
  );
  await assertFails(
    deleteDoc(favoriteDoc(anonymousDb, 'favorite-owner', 'banana')),
  );

  await assertFails(
    getDoc(favoriteDoc(otherUserDb, 'favorite-owner', 'banana')),
  );
  await assertFails(
    getDocs(collection(otherUserDb, 'users', 'favorite-owner', 'favorites')),
  );
  await assertFails(
    setDoc(
      favoriteDoc(otherUserDb, 'favorite-owner', 'orange'),
      favorite('orange'),
    ),
  );
  await assertFails(
    deleteDoc(favoriteDoc(otherUserDb, 'favorite-owner', 'banana')),
  );
});

test('Favorites reject mismatched IDs, missing fields, extras, and bad timestamps', async () => {
  const db = testEnv.authenticatedContext('invalid-favorite').firestore();

  await assertFails(
    setDoc(
      favoriteDoc(db, 'invalid-favorite', 'banana'),
      favorite('orange'),
    ),
  );
  await assertFails(
    setDoc(
      favoriteDoc(db, 'invalid-favorite', 'banana'),
      favorite('banana', { unexpected: true }),
    ),
  );
  await assertFails(
    setDoc(
      favoriteDoc(db, 'invalid-favorite', 'banana'),
      favorite('banana', { addedAt: Timestamp.now() }),
    ),
  );
  await assertFails(
    setDoc(
      favoriteDoc(db, 'invalid-favorite', 'banana'),
      { productId: 'banana' },
    ),
  );
  await assertFails(
    setDoc(
      favoriteDoc(db, 'invalid-favorite', '   '),
      favorite('   '),
    ),
  );
});

test('owner cannot access a non-primary address document', async () => {
  const db = testEnv.authenticatedContext('other-address').firestore();
  const ref = doc(db, 'users', 'other-address', 'addresses', 'secondary');

  await assertFails(getDoc(ref));
  await assertFails(setDoc(ref, address()));
});

test('unauthenticated users cannot read or write either document path', async () => {
  const db = testEnv.unauthenticatedContext().firestore();

  await assertFails(getDoc(userDoc(db, 'anonymous')));
  await assertFails(setDoc(userDoc(db, 'anonymous'), profile()));
  await assertFails(getDoc(addressDoc(db, 'anonymous')));
  await assertFails(setDoc(addressDoc(db, 'anonymous'), address()));
});

test('one authenticated user cannot read or write another user’s documents', async () => {
  await seed('owner', 'users/owner', profile({ createdAt: new Date() }));
  await seed('owner', 'users/owner/addresses/primary', legacyAddress());
  const db = testEnv.authenticatedContext('attacker').firestore();

  await assertFails(getDoc(userDoc(db, 'owner')));
  await assertFails(setDoc(userDoc(db, 'owner'), profile()));
  await assertFails(getDoc(addressDoc(db, 'owner')));
  await assertFails(setDoc(addressDoc(db, 'owner'), address()));
});

test('unexpected profile and address fields are rejected', async () => {
  const db = testEnv.authenticatedContext('schema-owner').firestore();

  await assertFails(
    setDoc(userDoc(db, 'schema-owner'), profile({ isAdmin: true })),
  );
  await assertFails(
    setDoc(addressDoc(db, 'schema-owner'), address({ deliveryNotes: 'Side door' })),
  );
});

test('missing or invalid required profile values are rejected', async () => {
  const db = testEnv.authenticatedContext('invalid-profile').firestore();
  const cases = [
    (() => {
      const value = profile();
      delete value.fullName;
      return value;
    })(),
    (() => {
      const value = profile();
      delete value.email;
      return value;
    })(),
    (() => {
      const value = profile();
      delete value.mobileNumber;
      return value;
    })(),
    profile({ fullName: '  ' }),
    profile({ email: '' }),
    profile({ mobileNumber: 123 }),
    profile({ gender: 'other' }),
    profile({ createdAt: new Date() }),
  ];

  for (const value of cases) {
    await assertFails(setDoc(userDoc(db, 'invalid-profile'), value));
  }
});

test('missing or invalid required address values are rejected', async () => {
  const db = testEnv.authenticatedContext('invalid-address').firestore();
  const cases = [
    (() => {
      const value = address();
      delete value.city;
      return value;
    })(),
    (() => {
      const value = address();
      delete value.district;
      return value;
    })(),
    (() => {
      const value = address();
      delete value.streetName;
      return value;
    })(),
    (() => {
      const value = address();
      delete value.buildingNumber;
      return value;
    })(),
    address({ city: '   ' }),
    address({ district: null }),
    address({ updatedAt: new Date() }),
  ];

  for (const value of cases) {
    await assertFails(setDoc(addressDoc(db, 'invalid-address'), value));
  }
});

test('listing and deleting user documents remain denied', async () => {
  const db = testEnv.authenticatedContext('no-list-delete').firestore();

  await assertFails(getDocs(collection(db, 'users')));
  await assertFails(deleteDoc(userDoc(db, 'no-list-delete')));
  await assertFails(deleteDoc(addressDoc(db, 'no-list-delete')));
});
