import shouldBehaveLikeGetStuff from './view/getStuff';
import shouldBehaveLikeUpdate from './effects/update';

export function shouldBehaveLikeUniswapPriceFeed(): void {
  describe('View functions', () => {
    describe('getStuff', () => {
      shouldBehaveLikeGetStuff();
    });
  });

  describe('Effects functions', () => {
    describe('update', () => {
      shouldBehaveLikeUpdate();
    });
  });
}
