WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
TopPosts AS (
    SELECT 
        ap.PostId,
        ap.Title,
        ap.CreationDate,
        ap.CommentCount,
        ap.VoteCount,
        ap.UpVotes,
        ap.DownVotes,
        RANK() OVER (ORDER BY ap.VoteCount DESC) AS PostRank
    FROM 
        ActivePosts ap
    WHERE 
        ap.VoteCount > 0
)
SELECT 
    ru.DisplayName,
    ru.Reputation,
    tp.Title,
    tp.CommentCount,
    tp.VoteCount,
    tp.UpVotes,
    tp.DownVotes
FROM 
    RankedUsers ru
JOIN 
    TopPosts tp ON ru.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
WHERE 
    tp.PostRank <= 10
ORDER BY 
    ru.Reputation DESC, tp.VoteCount DESC;