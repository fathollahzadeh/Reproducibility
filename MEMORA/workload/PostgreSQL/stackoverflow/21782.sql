
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(COUNT(c.Id) FILTER (WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - 
                 SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes,
        p.CreationDate,
        EXTRACT(YEAR FROM p.CreationDate) AS CreationYear
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATE '2024-10-01' - INTERVAL '5 years'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate
),
PopularQuestions AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.NetVotes,
        rp.CreationYear,
        CASE 
            WHEN rp.Score >= 100 THEN 'Hot'
            WHEN rp.Score >= 50 THEN 'Warm'
            ELSE 'Cold'
        END AS Temperature
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS ReasonNames
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INTEGER) = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)
SELECT 
    pq.Title,
    pq.ViewCount,
    pq.Score,
    pq.CommentCount,
    pq.NetVotes,
    pq.Temperature,
    cr.ReasonNames
FROM 
    PopularQuestions pq
LEFT JOIN 
    CloseReasons cr ON pq.Id = cr.PostId
ORDER BY 
    pq.ViewCount DESC NULLS LAST,
    pq.Score DESC
LIMIT 100;
