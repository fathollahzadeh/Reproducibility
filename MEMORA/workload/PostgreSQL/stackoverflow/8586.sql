
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.OwnerUserId, p.Score
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerName,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByScore <= 3 
)
SELECT 
    t.OwnerName,
    COUNT(t.PostId) AS TotalPosts,
    SUM(t.UpVotes) AS TotalUpVotes,
    SUM(t.DownVotes) AS TotalDownVotes,
    AVG(t.CommentCount) AS AvgCommentsPerPost,
    STRING_AGG(t.Title, '; ') AS PostTitles
FROM 
    TopPosts t
GROUP BY 
    t.OwnerName
ORDER BY 
    TotalPosts DESC, TotalUpVotes DESC;
