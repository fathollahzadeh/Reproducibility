WITH PostAggregates AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        MAX(ph.CreationDate) AS LastHistoryEntryDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.PostTypeId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadges,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pt.Name AS PostTypeName,
    pa.CommentCount,
    pa.VoteCount,
    pa.LastHistoryEntryDate,
    ur.DisplayName AS AuthorDisplayName,
    ur.TotalBadges,
    ur.AvgReputation
FROM 
    PostAggregates pa
JOIN 
    PostTypes pt ON pa.PostTypeId = pt.Id
JOIN 
    Users au ON pa.PostId = au.Id
JOIN 
    UserReputation ur ON au.Id = ur.UserId
ORDER BY 
    pa.VoteCount DESC,
    pa.CommentCount DESC
LIMIT 100;