import { NextResponse } from 'next/server';

export async function POST(request: Request) {
  try {
    const { username, password } = await request.json();

    if (!username || !password) {
      return NextResponse.json(
        { error: 'Username and password are required.' },
        { status: 400 }
      );
    }

    console.log(`Login attempt: username=${username}, password=***`);

    // Dummy authentication for demonstration purposes.
    // Use the same credentials as defined in mongo-init.js
    if (username === 'admin' && password === 'admin') {
      console.log('Authentication successful');
      return NextResponse.json(
        { message: 'Login successful', token: 'dummy-token' },
        { status: 200 }
      );
    }

    console.log('Authentication failed: Invalid credentials');
    return NextResponse.json(
      { error: 'Invalid credentials' },
      { status: 401 }
    );
  } catch (error) {
    console.error('Login error:', error);
    return NextResponse.json(
      { error: 'Invalid request' },
      { status: 400 }
    );
  }
}
