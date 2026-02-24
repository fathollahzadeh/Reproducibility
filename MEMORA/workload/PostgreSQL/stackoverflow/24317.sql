
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY CASE WHEN p.ParentId IS NOT NULL THEN 1 ELSE 0 END ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS DownVotesCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
),
UserAnalysis AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        AVG(u.Reputation) AS AvgReputation,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    WHERE 
        u.LastAccessDate > CURRENT_TIMESTAMP - INTERVAL '6 months'
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT CONCAT(ph.Comment, ' (', CAST(ph.CreationDate AS date), ')'), '; ') AS HistoryComments,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '3 months'
    GROUP BY 
        ph.PostId
),
FinalReport AS (
    SELECT 
        up.UserId,
        up.DisplayName,
        up.AvgReputation,
        up.PostsCount,
        up.QuestionsCount,
        up.AnswersCount,
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.UpVotesCount,
        rp.DownVotesCount,
        COALESCE(ph.HistoryComments, 'No history') AS PostHistory,
        ph.HistoryCount AS PostHistoryCount
    FROM 
        UserAnalysis up
    INNER JOIN 
        RankedPosts rp ON up.UserId = rp.PostId  
    LEFT JOIN 
        PostHistoryDetails ph ON rp.PostId = ph.PostId
    WHERE 
        rp.rn = 1  
    ORDER BY 
        up.AvgReputation DESC, rp.ViewCount DESC
)
SELECT 
    *
FROM 
    FinalReport
WHERE 
    COALESCE(PostHistoryCount, 0) > 1
    AND UpVotesCount > DownVotesCount
    AND (QuestionsCount > 0 OR AnswersCount > 0)
    AND NOT EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE p.OwnerUserId = FinalReport.UserId 
        AND p.CreationDate < CURRENT_TIMESTAMP - INTERVAL '1 year'
    )
ORDER BY 
    CreationDate DESC
LIMIT 50 OFFSET 0;
