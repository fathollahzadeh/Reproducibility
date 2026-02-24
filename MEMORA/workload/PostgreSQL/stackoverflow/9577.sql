
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 month'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName, p.PostTypeId
),
TopRankedPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        OwnerDisplayName, 
        CommentCount, 
        UpVoteCount, 
        DownVoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    trp.*, 
    pt.Name AS PostTypeName, 
    bt.Name AS BadgeName, 
    CASE 
        WHEN trp.UpVoteCount > trp.DownVoteCount THEN 'Positive'
        WHEN trp.UpVoteCount < trp.DownVoteCount THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    TopRankedPosts trp
LEFT JOIN 
    PostTypes pt ON pt.Id = (SELECT PostTypeId FROM Posts WHERE Id = trp.PostId LIMIT 1)
LEFT JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = trp.PostId LIMIT 1)
LEFT JOIN 
    (SELECT Name, UserId FROM Badges WHERE Class = 1 ORDER BY Date DESC LIMIT 1) bt ON bt.UserId = b.UserId
ORDER BY 
    trp.Score DESC, trp.CreationDate DESC;
