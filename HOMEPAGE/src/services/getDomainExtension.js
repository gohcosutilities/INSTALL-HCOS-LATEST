import { useDomainExtensionsStore } from '@/store/domainExtensions';

export const getDomainExtension = async (fullDomain) => {
  const store = useDomainExtensionsStore();
  return await store.getDomainExtension(fullDomain);
};

export const extractDomainName = async (fullDomain) => {
  const store = useDomainExtensionsStore();
  return await store.extractDomainName(fullDomain);
};
