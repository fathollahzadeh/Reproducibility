
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopAnswerers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(a.Id) AS AnswerCount,
        SUM(a.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts a ON u.Id = a.OwnerUserId
    WHERE 
        a.PostTypeId = 2 AND 
        a.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(a.Id) > 5
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
TopPostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        pha.EditCount,
        pha.LastEditDate,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC) AS AllTimeRank
    FROM 
        RankedPosts rp
    JOIN 
        PostHistoryAggregates pha ON rp.PostId = pha.PostId
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tpa.Title,
    tpa.ViewCount,
    tpa.Score,
    tpa.AnswerCount,
    tpa.EditCount,
    tpa.LastEditDate,
    tua.DisplayName AS TopAnswerer,
    tua.AnswerCount AS AnswererPostCount,
    tua.TotalScore AS AnswererTotalScore
FROM 
    TopPostDetails tpa
JOIN 
    TopAnswerers tua ON EXISTS (SELECT 1 FROM Posts p WHERE p.ParentId = tpa.PostId)
ORDER BY 
    tpa.AllTimeRank;
