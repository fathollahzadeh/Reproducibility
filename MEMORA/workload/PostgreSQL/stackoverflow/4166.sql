WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        DisplayName,
        Reputation,
        Rank() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        Users
), 
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(pa.AnswerCount, 0) AS AnswerCount,
        CASE 
            WHEN p.PostTypeId = 1 THEN 'Question'
            WHEN p.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostType
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) pc ON p.Id = pc.PostId
    LEFT JOIN (
        SELECT 
            ParentId AS PostId, 
            COUNT(*) AS AnswerCount 
        FROM 
            Posts 
        WHERE 
            PostTypeId = 2 
        GROUP BY 
            ParentId
    ) pa ON p.Id = pa.PostId
), 
PostHistoryAggregates AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    JOIN 
        Posts p ON ph.PostId = p.Id
    GROUP BY 
        p.Id
),
PostAuthorReputation AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.ViewCount,
        pm.Score,
        COALESCE(ur.Reputation, 0) AS AuthorReputation,
        ur.DisplayName AS AuthorDisplayName
    FROM 
        PostMetrics pm
    LEFT JOIN 
        UserReputation ur ON pm.OwnerUserId = ur.UserId
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.ViewCount,
    pa.Score,
    pa.AuthorReputation,
    pa.AuthorDisplayName,
    COALESCE(ph.HistoryTypes, 'No history') AS PostHistory,
    COALESCE(ph.HistoryCount, 0) AS TotalHistoryEntries
FROM 
    PostAuthorReputation pa
LEFT JOIN 
    PostHistoryAggregates ph ON pa.PostId = ph.PostId
WHERE 
    (pa.PostId IS NOT NULL)
    AND (pa.AuthorReputation > 1000 OR pa.ViewCount > 100)
ORDER BY 
    pa.Score DESC, pa.ViewCount DESC
LIMIT 50;
