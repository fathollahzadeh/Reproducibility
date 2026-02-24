
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(DISTINCT v.Id) DESC) AS PostRank,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
), FilteredPosts AS (
    SELECT 
        PostId, Title, CreationDate, CommentCount, VoteCount, UpVotes, DownVotes, OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
)
SELECT 
    f.OwnerDisplayName,
    f.Title,
    f.CreationDate,
    f.CommentCount,
    f.VoteCount,
    f.UpVotes,
    f.DownVotes,
    (f.UpVotes - f.DownVotes) AS NetScore
FROM 
    FilteredPosts f
ORDER BY 
    NetScore DESC, f.CommentCount DESC;
