import { useState, useRef } from 'react';

export const useFormInputs = (fields: string[]) => {
  const initialInputs = fields.reduce((acc, field) => {
    acc[field] = '';
    return acc;
  }, {} as Record<string, string>);

  const [inputs, setInputs] = useState<Record<string, string>>(initialInputs);
  const inputRefs = useRef<Record<string, HTMLInputElement | null>>({});

  const handleInputChange = (field: string, value: string) => {
    setInputs(prev => ({
      ...prev,
      [field]: value
    }));
  };

  return {
    inputs,
    handleInputChange,
    inputRefs
  };
};
