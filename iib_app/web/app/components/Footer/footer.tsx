import React from "react";

const Footer: React.FC = () => {
  return (
    <footer className="p-2 border-t text-center text-sm">
      &copy; {new Date().getFullYear()} IIB-GPU-Cluster
    </footer>
  );
};

export default Footer;
