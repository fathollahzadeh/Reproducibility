WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerRank,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY p.Id) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY p.Id) AS DownvoteCount
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
LatestBadges AS (
    SELECT 
        b.UserId,
        b.Name AS BadgeName,
        ROW_NUMBER() OVER (PARTITION BY b.UserId ORDER BY b.Date DESC) AS BadgeRank
    FROM 
        Badges b
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts p ON p.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(p.Id) > 10
)
SELECT 
    rp.Title,
    rp.OwnerDisplayName,
    rb.BadgeName,
    rp.Score AS PostScore,
    rp.ViewCount,
    pt.TagName,
    (rp.UpvoteCount - rp.DownvoteCount) AS NetVotes,
    rp.CreationDate
FROM 
    RankedPosts rp
LEFT JOIN 
    LatestBadges rb ON rp.OwnerUserId = rb.UserId AND rb.BadgeRank = 1
JOIN 
    PopularTags pt ON rp.Title LIKE '%' || pt.TagName || '%'
WHERE 
    rp.OwnerRank <= 3
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;