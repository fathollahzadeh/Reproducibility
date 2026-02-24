WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(DISTINCT a.Id) DESC, COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) DESC) AS Rank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Posts a ON a.ParentId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    WHERE p.PostTypeId = 1 
    GROUP BY p.Id, p.Title, p.CreationDate, u.DisplayName
), 
CommentedPosts AS (
    SELECT 
        rp.Id, 
        rp.Title, 
        rp.CreationDate, 
        rp.OwnerDisplayName, 
        rp.AnswerCount, 
        rp.UpVotes, 
        rp.DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM RankedPosts rp
    LEFT JOIN Comments c ON c.PostId = rp.Id
    GROUP BY rp.Id, rp.Title, rp.CreationDate, rp.OwnerDisplayName, rp.AnswerCount, rp.UpVotes, rp.DownVotes
)

SELECT 
    cp.Title, 
    cp.OwnerDisplayName, 
    cp.CreationDate, 
    cp.AnswerCount, 
    cp.UpVotes, 
    cp.DownVotes, 
    cp.CommentCount,
    RANK() OVER (ORDER BY cp.UpVotes - cp.DownVotes DESC) AS PopularityRank
FROM CommentedPosts cp
WHERE cp.AnswerCount > 0
ORDER BY PopularityRank
LIMIT 10;