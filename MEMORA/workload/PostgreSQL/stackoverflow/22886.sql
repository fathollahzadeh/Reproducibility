
WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.Score, 
        p.Tags, 
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(p.ViewCount, 0) AS ViewCountAdjusted,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.Score IS NOT NULL
), 
PopularTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, ',')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        unnest(string_to_array(p.Tags, ',')) 
    HAVING 
        COUNT(*) > 5 
), 
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId IN (2, 6) THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.Title,
    rp.Score,
    rp.ViewCountAdjusted,
    ut.DisplayName,
    ut.BadgeCount,
    pt.Tag,
    pt.TagCount,
    CASE 
        WHEN ut.UpVotesCount IS NULL THEN 'No Votes'
        ELSE 'Votes Counted'
    END AS VotesStatus,
    COALESCE(rp.Rank, 0) AS PostRank,
    CASE
        WHEN rp.ViewCountAdjusted > 1000 THEN 'Highly Viewed'
        ELSE 'Less Viewed'
    END AS ViewCategory,
    (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = rp.OwnerUserId AND p.PostTypeId = 2) AS AnswersCount
FROM 
    RankedPosts rp
JOIN 
    UserStatistics ut ON rp.OwnerUserId = ut.UserId
LEFT JOIN 
    PopularTags pt ON pt.Tag = ANY(string_to_array(rp.Tags, ','))
WHERE 
    rp.Rank <= 5
    AND (ut.UpVotesCount > ut.DownVotesCount OR ut.BadgeCount >= 1)
ORDER BY 
    rp.Score DESC, 
    ut.BadgeCount DESC;
