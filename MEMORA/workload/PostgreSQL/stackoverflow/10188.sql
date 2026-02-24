
WITH Benchmarking AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.Reputation AS OwnerReputation,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        PT.Name AS PostType,
        PH.PostHistoryTypeId,
        PH.CreationDate AS HistoryCreationDate
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory PH ON p.Id = PH.PostId
    LEFT JOIN 
        PostTypes PT ON p.PostTypeId = PT.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.Reputation, PT.Name, PH.PostHistoryTypeId, PH.CreationDate
)
SELECT 
    *,
    ROW_NUMBER() OVER (ORDER BY Score DESC, ViewCount DESC) AS Ranking
FROM 
    Benchmarking
ORDER BY 
    Ranking
LIMIT 100;
