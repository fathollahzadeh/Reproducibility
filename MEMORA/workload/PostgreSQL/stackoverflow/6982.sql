WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN Posts a ON p.Id = a.ParentId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopRankedPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, AnswerCount, UpVotes, DownVotes, Rank
    FROM 
        RankedPosts
    WHERE 
        Rank <= 50
)
SELECT 
    tr.PostId,
    tr.Title,
    tr.CreationDate,
    tr.Score,
    tr.ViewCount,
    tr.AnswerCount,
    tr.UpVotes,
    tr.DownVotes,
    u.DisplayName AS AuthorName,
    u.Reputation,
    u.CreationDate AS UserCreationDate
FROM 
    TopRankedPosts tr
JOIN 
    Users u ON tr.PostId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE Id = tr.PostId)
ORDER BY 
    tr.Rank;