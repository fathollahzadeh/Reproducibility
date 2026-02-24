
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.LastActivityDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(co.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments co ON p.Id = co.PostId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.LastActivityDate, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        PostId, Title, Score, CreationDate, LastActivityDate, OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
VoteSummary AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    t.PostId,
    t.Title,
    t.Score,
    t.CreationDate,
    t.LastActivityDate,
    t.OwnerDisplayName,
    v.UpVotes,
    v.DownVotes,
    CASE 
        WHEN v.UpVotes + v.DownVotes > 0 THEN ROUND((v.UpVotes * 1.0 / (v.UpVotes + v.DownVotes)) * 100, 2)
        ELSE 0 
    END AS UpVotePercentage
FROM 
    TopRankedPosts t
JOIN 
    VoteSummary v ON t.PostId = v.PostId
ORDER BY 
    t.Score DESC, t.PostId;
