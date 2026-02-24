
WITH RECURSIVE RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
    UNION ALL
    SELECT 
        a.Id AS PostId,
        a.Title,
        a.CreationDate,
        a.Score,
        a.OwnerUserId,
        r.Level + 1 AS Level
    FROM 
        Posts a
    INNER JOIN 
        RecursiveCTE r ON a.ParentId = r.PostId
    WHERE 
        a.PostTypeId = 2 
),
PostVotes AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)

SELECT 
    q.PostId AS QuestionId,
    q.Title AS QuestionTitle,
    q.CreationDate AS QuestionDate,
    q.Score AS QuestionScore,
    u.DisplayName AS Owner,
    COALESCE(v.UpVotes, 0) AS TotalUpVotes,
    COALESCE(v.DownVotes, 0) AS TotalDownVotes,
    COALESCE(v.TotalVotes, 0) AS TotalVotes,
    COALESCE(b.BadgeCount, 0) AS OwnerBadges,
    COALESCE(phs.EditCount, 0) AS TotalEdits,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = q.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Posts a WHERE a.ParentId = q.PostId) AS AnswerCount
FROM 
    RecursiveCTE q
LEFT JOIN 
    Users u ON q.OwnerUserId = u.Id
LEFT JOIN 
    PostVotes v ON q.PostId = v.PostId
LEFT JOIN 
    UserReputation b ON u.Id = b.UserId
LEFT JOIN 
    PostHistorySummary phs ON q.PostId = phs.PostId
WHERE 
    q.Level = 1 
ORDER BY 
    q.Score DESC, 
    q.CreationDate DESC
LIMIT 100;
