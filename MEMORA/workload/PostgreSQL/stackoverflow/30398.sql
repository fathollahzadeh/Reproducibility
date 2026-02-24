WITH RECURSIVE PostHierarchy AS (
    SELECT 
        Id, 
        Title, 
        ParentId, 
        1 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.Id
),
UserVotes AS (
    SELECT 
        UserId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        UserId
),
PostAnalytics AS (
    SELECT 
        p.Id,
        p.Title,
        ph.Level,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId = 12) AS DeleteCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHierarchy ph ON p.Id = ph.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UserVotes v ON p.OwnerUserId = v.UserId
)
SELECT 
    pa.Title,
    pa.OwnerDisplayName,
    pa.CreationDate,
    pa.Level,
    pa.UpVotes,
    pa.DownVotes,
    pa.CommentCount,
    pa.DeleteCount,
    (pa.UpVotes - pa.DownVotes) AS VoteBalance,
    CASE 
        WHEN pa.DeleteCount > 0 THEN 'Deleted'
        ELSE 'Active'
    END AS PostStatus
FROM 
    PostAnalytics pa
WHERE 
    pa.Level = 1  
    AND pa.CommentCount > 0
ORDER BY 
    pa.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;