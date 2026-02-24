
WITH RECURSIVE PostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
    UNION ALL
    SELECT 
        a.Id,
        a.Title,
        a.Body,
        a.CreationDate,
        a.OwnerUserId,
        a.Score,
        a.ParentId,
        Level + 1
    FROM 
        Posts a
    INNER JOIN 
        PostCTE q ON a.ParentId = q.Id
    WHERE 
        a.PostTypeId = 2  
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS RN
    FROM 
        Users u
    WHERE 
        u.Reputation > 0
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
ClosePosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        ph.UserId,
        ph.UserDisplayName,
        pt.Name AS PostHistoryType
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        pt.Name IN ('Post Closed', 'Post Reopened')
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS QuestionDate,
    u.DisplayName AS OwnerName,
    COALESCE(r.Reputation, 0) AS OwnerReputation,
    COALESCE(vs.VoteCount, 0) AS TotalVotes,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN cp.PostId IS NOT NULL THEN 'Yes' 
        ELSE 'No' 
    END AS IsClosed,
    COUNT(DISTINCT c.Id) AS CommentCount
FROM 
    PostCTE p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserReputation r ON u.Id = r.UserId
LEFT JOIN 
    PostVoteStats vs ON p.Id = vs.PostId
LEFT JOIN 
    ClosePosts cp ON p.Id = cp.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.Level = 0
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName, r.Reputation, vs.VoteCount, vs.UpVotes, vs.DownVotes, cp.PostId
ORDER BY 
    p.CreationDate DESC;
