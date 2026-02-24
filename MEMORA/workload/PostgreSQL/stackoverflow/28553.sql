WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days' 
        AND p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CommentCount,
        rp.BadgeCount,
        rp.UpVoteCount,
        u.DisplayName AS OwnerDisplayName
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    WHERE 
        rp.UserPostRank <= 5
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostsCreated
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '90 days'
    GROUP BY 
        u.Id
    ORDER BY 
        PostsCreated DESC
    LIMIT 10
)
SELECT 
    t.Title,
    t.CommentCount,
    t.BadgeCount,
    t.UpVoteCount,
    t.OwnerDisplayName,
    mau.DisplayName AS MostActiveUser,
    mau.PostsCreated
FROM 
    TopPosts t
JOIN 
    MostActiveUsers mau ON t.OwnerDisplayName = mau.DisplayName;