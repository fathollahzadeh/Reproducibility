WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT r.PostId) AS PostsCount,
        SUM(r.CommentCount) AS TotalComments,
        SUM(r.AnswerCount) AS TotalAnswers,
        SUM(r.UpVotes) AS TotalUpVotes,
        SUM(r.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    JOIN 
        RankedPosts r ON u.Id = r.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    ur.UserId,
    ur.Reputation,
    ur.PostsCount,
    ur.TotalComments,
    ur.TotalAnswers,
    ur.TotalUpVotes,
    ur.TotalDownVotes,
    ROW_NUMBER() OVER (ORDER BY ur.Reputation DESC) AS UserRank
FROM 
    UserReputation ur
WHERE 
    ur.Reputation > 1000 
ORDER BY 
    ur.Reputation DESC, ur.PostsCount DESC;