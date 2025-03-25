import Link from 'next/link';
import Image from 'next/image';

export default function Header() {
  return (
    <header className="w-full bg-black text-white p-4">
      <div className="container mx-auto flex justify-between items-center">
        <Link href="/" className="flex items-center gap-3">
          <div className="relative w-8 h-8 flex-shrink-0">
            <Image
              src="/models3.svg"
              alt="logo"
              fill
              className="dark:invert object-contain"
            />
          </div>
          <span className="text-xl font-bold">IIB Cluster Interface</span>
        </Link>

        {/* Navigation can be added here

        <nav className="hidden md:flex space-x-4">
          <Link href="/dashboard" className="hover:text-gray-300">Dashboard</Link>
          <Link href="/jobs" className="hover:text-gray-300">Jobs</Link>
          <Link href="/filesystem" className="hover:text-gray-300">Filesystem</Link>
          <Link href="/users" className="hover:text-gray-300">Users</Link>
        </nav>
        */}
      </div>
    </header>
  );
}
