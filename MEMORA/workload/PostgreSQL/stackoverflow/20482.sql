WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY p.Id
),

FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        CASE 
            WHEN rp.RankScore <= 10 THEN 'Top Post'
            WHEN rp.Score > 100 THEN 'Highly Rated'
            ELSE 'Regular Post'
        END AS PostCategory
    FROM RankedPosts rp
    WHERE (rp.UpVoteCount - rp.DownVoteCount) > 0 
      AND rp.RankScore <= 50 
      AND rp.Title NOT LIKE '%[closed]%'
),

UserLastPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS UserPostCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id
),

PostLinkStats AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS RelatedPostCount,
        STRING_AGG(DISTINCT lt.Name, ', ') AS LinkTypeNames
    FROM PostLinks pl
    INNER JOIN LinkTypes lt ON pl.LinkTypeId = lt.Id
    GROUP BY pl.PostId
),

FinalResult AS (
    SELECT 
        fp.Title,
        fp.CreationDate,
        fp.Score,
        fp.ViewCount,
        fp.UpVoteCount,
        fp.DownVoteCount,
        fp.PostCategory,
        ul.DisplayName AS UserDisplayName,
        ul.UserPostCount,
        ul.LastPostDate,
        pls.RelatedPostCount,
        pls.LinkTypeNames
    FROM FilteredPosts fp
    LEFT JOIN UserLastPosts ul ON fp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ul.UserId)
    LEFT JOIN PostLinkStats pls ON fp.PostId = pls.PostId
)

SELECT 
    fr.Title,
    fr.CreationDate,
    fr.Score,
    fr.ViewCount,
    fr.UpVoteCount,
    fr.DownVoteCount,
    fr.PostCategory,
    fr.UserDisplayName,
    fr.UserPostCount,
    fr.LastPostDate,
    COALESCE(fr.RelatedPostCount, 0) AS RelatedPostCount,
    COALESCE(fr.LinkTypeNames, 'No Links') AS LinkTypeNames
FROM FinalResult fr
WHERE fr.UserPostCount IS NOT NULL
ORDER BY fr.Score DESC, fr.ViewCount DESC;