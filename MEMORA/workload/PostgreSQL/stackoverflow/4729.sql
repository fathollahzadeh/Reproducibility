WITH PostInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 24) 
    GROUP BY 
        ph.PostId
),
UserRanks AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
)
SELECT 
    pi.PostId,
    pi.Title,
    pi.CreationDate,
    pi.Score,
    pi.ViewCount,
    pi.OwnerDisplayName,
    pi.CommentCount,
    pi.UpVotes,
    COALESCE(phs.EditCount, 0) AS TotalEdits,
    phs.LastEditDate,
    CASE 
        WHEN ur.ReputationRank <= 10 THEN 'Top Contributor'
        WHEN ur.ReputationRank BETWEEN 11 AND 50 THEN 'Contributor'
        ELSE 'New User'
    END AS UserCategory
FROM 
    PostInfo pi
LEFT JOIN 
    PostHistoryStats phs ON pi.PostId = phs.PostId
LEFT JOIN 
    Users u ON pi.OwnerDisplayName = u.DisplayName
LEFT JOIN 
    UserRanks ur ON u.Id = ur.UserId
ORDER BY 
    pi.Score DESC, pi.UpVotes DESC;