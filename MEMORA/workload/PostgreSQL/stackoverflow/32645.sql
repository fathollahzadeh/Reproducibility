WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 month'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        up.TotalPosts,
        up.Questions,
        up.Answers
    FROM 
        Users u
    JOIN 
        UserPostCounts up ON u.Id = up.UserId
    WHERE 
        u.Reputation >= 500
    ORDER BY 
        u.Reputation DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    phd.PostHistoryTypeId,
    phd.CreationDate AS HistoryDate,
    phd.UserDisplayName AS Editor,
    phd.Comment AS EditComment,
    tu.DisplayName AS TopUser,
    tu.Reputation AS UserReputation,
    tu.TotalPosts AS UserPostCount,
    tu.Questions AS UserQuestions,
    tu.Answers AS UserAnswers
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
LEFT JOIN 
    TopUsers tu ON rp.AcceptedAnswerId = tu.UserId
WHERE 
    rp.Rank <= 5
    AND (phd.PostHistoryTypeId IS NULL OR phd.PostHistoryTypeId IN (1, 4, 10))
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;