
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN p.Id END) AS AcceptedCount,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        QuestionCount,
        AcceptedCount,
        TotalScore,
        TotalCommentScore,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC, AcceptedCount DESC) AS Rank
    FROM 
        UserActivity
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        p.Score,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(ph.EditCount, 0) AS EditCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) pc ON p.Id = pc.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS EditCount
        FROM 
            PostHistory
        WHERE 
            PostHistoryTypeId IN (4, 5) 
        GROUP BY 
            PostId
    ) ph ON p.Id = ph.PostId
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.CommentCount,
    pd.EditCount,
    CASE 
        WHEN tu.AcceptedCount > 0 THEN 'Has Accepted Answers'
        ELSE 'No Accepted Answers'
    END AS AnswerStatus,
    CASE 
        WHEN tu.Rank <= 10 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserType
FROM 
    TopUsers tu
JOIN 
    PostDetails pd ON tu.UserId = pd.OwnerUserId
WHERE 
    pd.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
ORDER BY 
    tu.Rank, pd.Score DESC;
