
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.Score,
        p.CreationDate,
        p.Title,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(CHAR_LENGTH(p.Body), 0) AS BodyLength,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT AVG(U.Reputation) 
         FROM Users U 
         WHERE U.Id IN (SELECT U2.Id 
                        FROM Users U2 
                        JOIN Votes V ON U2.Id = V.UserId 
                        WHERE V.PostId = p.Id AND V.VoteTypeId = 2)) AS AverageReputation
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.Rank,
    rp.BodyLength,
    rp.CommentCount,
    CASE 
        WHEN rp.OwnerUserId IS NOT NULL THEN 
            (SELECT DisplayName FROM Users WHERE Id = rp.OwnerUserId)
        ELSE 
            'Community User'
    END AS OwnerDisplayName,
    CASE 
        WHEN rp.AverageReputation IS NOT NULL THEN 
            rp.AverageReputation
        ELSE 
            0
    END AS UserAverageReputation,
    CASE 
        WHEN rp.Rank = 1 THEN 'Most Popular'
        WHEN rp.Rank <= 5 THEN 'Top Posts'
        ELSE 'Other Posts'
    END AS PopularityCategory
FROM 
    RankedPosts rp
WHERE 
    (rp.Score > 10 OR rp.BodyLength > 500)
    AND NOT EXISTS (
        SELECT 1 
        FROM PostHistory ph 
        WHERE ph.PostId = rp.PostId 
        AND ph.PostHistoryTypeId = 12 /* Post Deleted */
    )
ORDER BY 
    rp.Rank, rp.Score DESC;
