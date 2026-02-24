
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY pt.Id ORDER BY p.CreationDate DESC) AS RankPerType,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL (
            SELECT 
                unnest(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags)-2), '><')) AS TagName
        ) AS t ON true
    WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, pt.Id
), 

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.Reputation) AS TotalReputation,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),

PostInteraction AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VoteBalance,
        MAX(ph.CreationDate) AS LastHistoryUpdate
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        p.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    rp.Tags,
    ur.DisplayName AS Author,
    ur.TotalReputation,
    ur.AvgReputation,
    pi.TotalVotes,
    pi.VoteBalance,
    pi.LastHistoryUpdate,
    CASE 
        WHEN pi.VoteBalance > 0 THEN 'Well Received'
        WHEN pi.VoteBalance < 0 THEN 'Controversial'
        ELSE 'Neutral'
    END AS ReceptionStatus
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
JOIN 
    PostInteraction pi ON pi.PostId = rp.PostId
WHERE 
    rp.RankPerType = 1
    AND ur.TotalReputation IS NOT NULL
    AND (pi.LastHistoryUpdate IS NULL OR pi.LastHistoryUpdate > rp.CreationDate)
ORDER BY 
    rp.ViewCount DESC, 
    rp.Score DESC
LIMIT 50;
