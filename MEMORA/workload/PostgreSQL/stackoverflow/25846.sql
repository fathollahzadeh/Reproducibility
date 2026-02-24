
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount, 
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(p.ViewCount) AS TotalViews,
        CONCAT(u.DisplayName, ' has answered ', CAST(SUM(CASE WHEN p.ParentId IS NOT NULL THEN 1 ELSE 0 END) AS VARCHAR), ' questions') AS AnswerString
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),

PostHistoryData AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate AS HistoryDate, 
        p.Title AS PostTitle,
        p.Body AS PostBody,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypeDescriptions
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId, p.Title, p.Body, ph.CreationDate
)

SELECT 
    us.DisplayName,
    us.Reputation,
    us.QuestionCount,
    us.AcceptedAnswers,
    us.TotalViews,
    us.AnswerString,
    rp.PostId,
    rp.Title AS LatestQuestionTitle,
    rp.Body AS LatestQuestionBody,
    rp.CreationDate AS LatestQuestionDate,
    rp.Score AS LatestQuestionScore,
    ph.HistoryTypeDescriptions
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.Rank = 1
LEFT JOIN 
    PostHistoryData ph ON rp.PostId = ph.PostId
WHERE 
    us.Reputation > 1000
ORDER BY 
    us.Reputation DESC, 
    rp.CreationDate DESC;
