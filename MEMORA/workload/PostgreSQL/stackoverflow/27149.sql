
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),

TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) >= 5 
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        pht.Name AS HistoryType,
        ph.Text AS HistoryText
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.QuestionCount,
    u.TotalScore,
    u.TotalViews,
    COUNT(p.PostId) AS RecentQuestions,
    SUM(p.Score) AS RecentScore,
    SUM(p.ViewCount) AS RecentViews,
    ARRAY_AGG(DISTINCT h.HistoryType) AS RecentHistoryTypes,
    STRING_AGG(DISTINCT h.HistoryText, '; ') AS RecentHistoryComments
FROM 
    TopUsers u
LEFT JOIN 
    RankedPosts p ON u.UserId = p.OwnerUserId AND p.PostRank <= 10 
LEFT JOIN 
    PostHistoryDetails h ON p.PostId = h.PostId
GROUP BY 
    u.UserId, u.DisplayName, u.QuestionCount, u.TotalScore, u.TotalViews
ORDER BY 
    u.TotalScore DESC, u.QuestionCount DESC;
