<script setup lang="ts">
import { useSetupStore } from '@/stores/setup'
import TextInput from '@/components/fields/TextInput.vue'
import NumberInput from '@/components/fields/NumberInput.vue'
import SelectInput from '@/components/fields/SelectInput.vue'

const store = useSetupStore()
const c = store.config.oscar

const currencyOptions = [
  { value: 'USD', label: 'USD — US Dollar' },
  { value: 'CAD', label: 'CAD — Canadian Dollar' },
  { value: 'EUR', label: 'EUR — Euro' },
  { value: 'GBP', label: 'GBP — British Pound' },
  { value: 'AUD', label: 'AUD — Australian Dollar' },
]

const registrarOptions = [
  { value: 'ENOM', label: 'ENOM' },
  { value: 'NAMESILO', label: 'NameSilo' },
  { value: 'DOMAINNAMEAPI', label: 'DomainNameAPI' },
]
</script>

<template>
  <div class="section">
    <h2 class="section-title">🛒 E-Commerce (Oscar)</h2>
    <div class="grid">
      <TextInput v-model="c.shopName" label="Shop Name" placeholder="My Shop" />
      <SelectInput v-model="c.defaultCurrency" label="Default Currency" :options="currencyOptions" />
      <SelectInput v-model="c.systemCurrency" label="System Currency" :options="currencyOptions" />
      <NumberInput v-model="c.taxRate" label="Tax Rate (%)" :min="0" :max="100" :step="0.5" />
      <NumberInput v-model="c.trialDays" label="Product Trial Days" :min="0" />
      <NumberInput v-model="c.authorizationAmount" label="Authorization Amount ($)" :min="0" :step="0.01" help-text="Payment method validation charge." />
      <SelectInput v-model="c.defaultRegistrar" label="Default Registrar" :options="registrarOptions" />
      <TextInput v-model="c.paidOrderStatus" label="Paid Order Status" placeholder="Processing" />
      <TextInput v-model="c.orderPaidLabel" label="Order Paid Label" placeholder="Paid" />
    </div>
  </div>
</template>

<style scoped>
.section { display: flex; flex-direction: column; gap: 20px; }
.section-title { font-size: 22px; font-weight: 700; color: var(--text-heading); }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 16px; background: var(--bg-card); padding: 20px; border-radius: var(--radius); border: 1px solid var(--border); }
</style>
