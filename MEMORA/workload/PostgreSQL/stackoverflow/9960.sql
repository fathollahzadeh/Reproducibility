WITH RankedPosts AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.CreationDate, 
           p.OwnerUserId, 
           u.DisplayName AS OwnerDisplayName, 
           p.Score, 
           p.ViewCount, 
           ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 AND p.Score > 0
),
PostVoteStats AS (
    SELECT pv.PostId, 
           COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes, 
           COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes
    FROM Votes pv
    JOIN VoteTypes vt ON pv.VoteTypeId = vt.Id
    GROUP BY pv.PostId
),
PostBadgeStats AS (
    SELECT b.UserId, 
           COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges, 
           COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges, 
           COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
FinalStats AS (
    SELECT rp.PostId, 
           rp.Title, 
           rp.CreationDate, 
           rp.OwnerUserId, 
           rp.OwnerDisplayName, 
           rp.Score, 
           rp.ViewCount, 
           pvs.UpVotes, 
           pvs.DownVotes, 
           COALESCE(bs.GoldBadges, 0) AS GoldBadges, 
           COALESCE(bs.SilverBadges, 0) AS SilverBadges, 
           COALESCE(bs.BronzeBadges, 0) AS BronzeBadges,
           rp.Rank
    FROM RankedPosts rp
    LEFT JOIN PostVoteStats pvs ON rp.PostId = pvs.PostId
    LEFT JOIN PostBadgeStats bs ON rp.OwnerUserId = bs.UserId
)
SELECT PostId, 
       Title, 
       CreationDate, 
       OwnerUserId, 
       OwnerDisplayName, 
       Score, 
       ViewCount, 
       UpVotes, 
       DownVotes, 
       GoldBadges, 
       SilverBadges, 
       BronzeBadges, 
       Rank
FROM FinalStats
WHERE Rank <= 100
ORDER BY Rank;
