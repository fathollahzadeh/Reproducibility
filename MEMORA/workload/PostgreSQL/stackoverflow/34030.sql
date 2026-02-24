WITH RECURSIVE PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, u.DisplayName, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.FavoriteCount
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 4 OR ph.PostHistoryTypeId = 5 
    GROUP BY 
        ph.PostId
)
SELECT 
    pa.Title,
    pa.CreationDate,
    pa.OwnerDisplayName,
    pa.Score,
    pa.ViewCount,
    pa.PostRank,
    COALESCE(phs.EditCount, 0) AS EditCount,
    phs.LastEditDate,
    (pa.TotalUpvotes - pa.TotalDownvotes) AS NetVotes,
    CASE 
        WHEN pa.TotalUpvotes IS NOT NULL THEN 
            CASE 
                WHEN pa.TotalUpvotes >= 100 THEN 'Highly Voted'
                WHEN pa.TotalUpvotes >= 50 THEN 'Moderately Voted'
                ELSE 'Low Votes'
            END
        ELSE 'No Votes'
    END AS VoteCategory
FROM 
    PostActivity pa
LEFT JOIN 
    PostHistoryStats phs ON pa.PostId = phs.PostId
WHERE 
    pa.Score > 10
    AND pa.ViewCount > 100
ORDER BY 
    pa.ViewCount DESC, pa.CreationDate DESC
LIMIT 50;