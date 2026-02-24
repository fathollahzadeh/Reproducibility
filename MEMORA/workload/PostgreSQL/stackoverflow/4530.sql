
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' AND
        p.Score IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        rn <= 10
),
PostStats AS (
    SELECT 
        t.OwnerDisplayName,
        SUM(t.ViewCount) AS TotalViews,
        AVG(t.Score) AS AverageScore,
        SUM(t.CommentCount) AS TotalComments
    FROM 
        TopPosts t
    GROUP BY 
        t.OwnerDisplayName
)

SELECT 
    ps.OwnerDisplayName,
    ps.TotalViews,
    ps.AverageScore,
    ps.TotalComments,
    COALESCE(b.Name, 'No Badge') AS BadgeName
FROM 
    PostStats ps
LEFT JOIN 
    Badges b ON b.UserId = (SELECT Id FROM Users WHERE DisplayName = ps.OwnerDisplayName LIMIT 1) AND b.Class = 1
ORDER BY 
    ps.TotalViews DESC
LIMIT 5;
