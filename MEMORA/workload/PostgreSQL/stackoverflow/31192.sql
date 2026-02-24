
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
MostActiveUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore
    FROM 
        RankedPosts
    GROUP BY 
        OwnerUserId
    HAVING 
        COUNT(*) > 5
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryCreationDate,
        pt.Name AS HistoryType,
        ph.UserDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    mah.PostCount,
    mah.TotalScore,
    p.Score AS LatestPostScore,
    COALESCE(SUM(CASE WHEN phd.HistoryRank = 1 THEN 1 ELSE 0 END), 0) AS RecentEdits,
    STRING_AGG(pt.Name, ', ') AS PostHistoryTags
FROM 
    RankedPosts rp
JOIN 
    MostActiveUsers mah ON rp.OwnerUserId = mah.OwnerUserId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId AND phd.HistoryRank <= 3
LEFT JOIN 
    Posts p ON p.Id = rp.PostId
LEFT JOIN 
    PostHistoryTypes pt ON pt.Id = (SELECT ph.PostHistoryTypeId FROM PostHistory ph WHERE ph.PostId = rp.PostId ORDER BY ph.CreationDate DESC LIMIT 1)
GROUP BY 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    mah.PostCount,
    mah.TotalScore,
    p.Score
ORDER BY 
    rp.CreationDate DESC;
