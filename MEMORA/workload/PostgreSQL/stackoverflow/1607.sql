WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        p.Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId, p.Tags
),
TopPosts AS (
    SELECT 
        r.Id,
        r.Title,
        r.CreationDate,
        r.Score,
        r.ViewCount,
        r.CommentCount,
        r.UpVotes,
        r.DownVotes,
        CASE 
            WHEN r.CommentCount > 10 THEN 'Highly Discussed'
            WHEN r.ViewCount > 1000 THEN 'Popular'
            ELSE 'Standard'
        END AS PostType
    FROM 
        RankedPosts r
    WHERE 
        r.rn = 1
),
UserSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    t.Title,
    t.CreationDate,
    t.Score,
    t.ViewCount,
    t.CommentCount,
    t.UpVotes,
    t.DownVotes,
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.TotalBadgeClass
FROM 
    TopPosts t
JOIN 
    UserSummary us ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = t.Id)
WHERE 
    t.PostType IN ('Highly Discussed', 'Popular')
ORDER BY 
    t.Score DESC, t.ViewCount DESC;