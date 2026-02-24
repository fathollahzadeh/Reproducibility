WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate AS PostCreationDate,
        u.DisplayName AS OwnerName,
        u.Reputation,
        (SELECT 
            COUNT(*) 
         FROM 
            Votes v 
         WHERE 
            v.PostId = p.Id 
            AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT 
            COUNT(*) 
         FROM 
            Votes v 
         WHERE 
            v.PostId = p.Id 
            AND v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        STRING_AGG(pt.Name, ', ') AS HistoryTypes,
        COUNT(*) AS HistoryCount,
        MIN(ph.CreationDate) AS FirstActionDate,
        MAX(ph.CreationDate) AS LastActionDate
    FROM 
        RecursivePostHistory ph
    INNER JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.ViewCount,
    pd.AnswerCount,
    pd.PostCreationDate,
    pd.OwnerName,
    pd.Reputation,
    pd.UpVotes,
    pd.DownVotes,
    pha.HistoryTypes,
    pha.HistoryCount,
    pha.FirstActionDate,
    pha.LastActionDate,
    CASE 
        WHEN pd.ViewCount > 1000 THEN 'Popular'
        WHEN pd.ViewCount BETWEEN 500 AND 1000 THEN 'Moderate'
        ELSE 'Less Popular'
    END AS PopularityCategory,
    CASE 
        WHEN pd.Reputation >= 1000 THEN 'Highly Reputable'
        ELSE 'Moderately Reputable'
    END AS ReputationCategory
FROM 
    PostDetails pd
LEFT JOIN 
    PostHistoryAggregates pha ON pd.PostId = pha.PostId
WHERE 
    pd.UpVotes > pd.DownVotes OR 
    EXISTS (
        SELECT 1 
        FROM Comments c 
        WHERE c.PostId = pd.PostId 
        AND c.Score > 10
    )
ORDER BY 
    pd.ViewCount DESC, 
    pd.PostCreationDate ASC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
