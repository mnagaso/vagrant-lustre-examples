import Link from 'next/link';
import Image from 'next/image';

export default function Header() {
  return (
    <header className="w-full bg-black text-white p-4">
      <div className="container mx-auto flex justify-between items-center">
        <Link href="/" className="flex items-center gap-2">
          <Image
            src="/logo.svg"
            alt="IIB GPU Cluster"
            width={32}
            height={32}
            className="dark:invert"
          />
          <span className="text-xl font-bold">IIB Cluster</span>
        </Link>

        <nav>
          <ul className="flex gap-6">
            <li>
              <Link href="/dashboard" className="hover:text-gray-300 transition-colors">
                Dashboard
              </Link>
            </li>
            <li>
              <Link href="/jobs" className="hover:text-gray-300 transition-colors">
                Jobs
              </Link>
            </li>
            <li>
              <Link href="/docs" className="hover:text-gray-300 transition-colors">
                Documentation
              </Link>
            </li>
          </ul>
        </nav>
      </div>
    </header>
  );
}
