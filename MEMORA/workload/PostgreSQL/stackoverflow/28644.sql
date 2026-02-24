
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 3 
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        (SELECT COUNT(Id) FROM Posts WHERE OwnerUserId = u.Id AND PostTypeId = 1) AS QuestionsCount
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000 
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    tp.Title,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes
FROM 
    UserReputation ur
JOIN 
    TopPosts tp ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
ORDER BY 
    ur.Reputation DESC, tp.UpVotes DESC;
