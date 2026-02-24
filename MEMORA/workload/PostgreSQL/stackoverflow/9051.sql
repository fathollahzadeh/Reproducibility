WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        U.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, ViewCount, Score, AnswerCount, CommentCount, OwnerName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
PostStats AS (
    SELECT 
        tp.OwnerName,
        COUNT(tp.PostId) AS PostCount,
        SUM(tp.ViewCount) AS TotalViews,
        SUM(tp.Score) AS TotalScore,
        AVG(tp.AnswerCount) AS AvgAnswers,
        AVG(tp.CommentCount) AS AvgComments
    FROM 
        TopPosts tp
    GROUP BY 
        tp.OwnerName
)
SELECT 
    ps.OwnerName,
    ps.PostCount,
    ps.TotalViews,
    ps.TotalScore,
    ps.AvgAnswers,
    ps.AvgComments,
    CASE 
        WHEN ps.PostCount > 20 THEN 'Veteran'
        WHEN ps.PostCount BETWEEN 10 AND 20 THEN 'Experienced'
        ELSE 'Newbie'
    END AS UserCategory
FROM 
    PostStats ps
ORDER BY 
    ps.TotalViews DESC;