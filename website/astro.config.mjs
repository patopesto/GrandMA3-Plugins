// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import starlightHeadingBadges from 'starlight-heading-badges';

// https://astro.build/config
export default defineConfig({
	site: 'https://grandma3.bambinito.net',
	integrations: [
		starlight({
			title: 'GrandMA3 plugins',
			social: [{ icon: 'github', label: 'Gitlab', href: 'https://github.com/patopesto/GrandMA3-Plugins' }],
			sidebar: [
				{
					label: 'Plugins',
					autogenerate: { directory: 'plugins' },
				},
				{
					label: 'Guides',
					autogenerate: { directory: 'guides' },
				},
				{
					label: 'Reference',
					items: [
						{ label: 'Introduction', slug: 'reference' },
						{ label: 'v2.3', autogenerate: { directory: 'reference/v2.3' }, badge: { text: 'Latest', variant: 'note' }},
						{ label: 'v2.2', autogenerate: { directory: 'reference/v2.2' }, collapsed: true },
						{ label: 'v2.1', autogenerate: { directory: 'reference/v2.1' }, collapsed: true },
						{ label: 'v2.0', autogenerate: { directory: 'reference/v2.0' }, collapsed: true },
					],
				},
			],
			plugins: [starlightHeadingBadges()],
		}),
	],
});
