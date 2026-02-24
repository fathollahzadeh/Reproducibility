
WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViews,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS TopContributors
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
    GROUP BY 
        t.TagName
),
CloseReasonStats AS (
    SELECT 
        crt.Name AS CloseReason,
        COUNT(ph.PostId) AS CloseCount,
        STRING_AGG(DISTINCT p.Title, '; ') AS ClosedPosts
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON CAST(ph.Comment AS INT) = crt.Id
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        crt.Name
),
PostDetail AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        COALESCE((SELECT TotalScore FROM TagStats WHERE PostCount > 1 LIMIT 1), 0) AS GangScore 
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, u.DisplayName
),
FinalStats AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.TotalScore,
        ts.AvgViews,
        cs.CloseReason,
        cs.CloseCount,
        cs.ClosedPosts,
        pd.PostId,
        pd.Title,
        pd.Author,
        pd.CommentCount,
        pd.VoteCount,
        pd.GangScore
    FROM 
        TagStats ts
    FULL OUTER JOIN 
        CloseReasonStats cs ON TRUE 
    LEFT JOIN 
        PostDetail pd ON pd.GangScore > 5 
    ORDER BY 
        ts.PostCount DESC, cs.CloseCount DESC, pd.VoteCount DESC
)
SELECT 
    COALESCE(TagName, 'N/A') AS TagName,
    COALESCE(PostCount, 0) AS PostCount,
    COALESCE(TotalScore, 0) AS TotalScore,
    COALESCE(AvgViews, 0) AS AvgViews,
    COALESCE(CloseReason, 'N/A') AS CloseReason,
    COALESCE(CloseCount, 0) AS CloseCount,
    COALESCE(ClosedPosts, 'N/A') AS ClosedPosts,
    COALESCE(PostId, 0) AS PostId,
    COALESCE(Title, 'N/A') AS Title,
    COALESCE(Author, 'Unknown') AS Author,
    COALESCE(CommentCount, 0) AS CommentCount,
    COALESCE(VoteCount, 0) AS VoteCount,
    COALESCE(GangScore, 0) AS GangScore
FROM 
    FinalStats;
