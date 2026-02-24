WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(P.Score) AS AvgPostScore,
        SUM(COALESCE(CAST(P.ViewCount AS BIGINT), 0)) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        PositivePosts,
        NegativePosts,
        AvgPostScore,
        TotalViews,
        RANK() OVER (ORDER BY TotalViews DESC) AS Rank
    FROM 
        UserPostStats
    WHERE 
        PostCount > 0
),
PostHistoryDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        PH.UserId,
        PH.UserDisplayName,
        PH.CreationDate AS HistoryDate,
        PHT.Name AS HistoryType,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    LEFT JOIN 
        Comments c ON c.PostId = P.Id
    WHERE 
        PH.UserId IS NOT NULL
    GROUP BY 
        P.Id, P.Title, P.CreationDate, PH.UserId, PH.UserDisplayName, PH.CreationDate, PHT.Name
)
SELECT 
    TU.Rank,
    TU.DisplayName,
    TU.PostCount,
    TU.PositivePosts,
    TU.NegativePosts,
    TU.AvgPostScore,
    TU.TotalViews,
    PHD.PostId,
    PHD.Title,
    PHD.CreationDate,
    PHD.HistoryDate,
    PHD.HistoryType,
    PHD.CommentCount,
    COALESCE(PHD.UserDisplayName, 'Anonymous') AS PostEditor
FROM 
    TopUsers TU
LEFT JOIN 
    PostHistoryDetails PHD ON TU.UserId = PHD.UserId
WHERE 
    TU.Rank <= 10 OR PHD.HistoryType IN ('Post Closed', 'Post Reopened')
ORDER BY 
    TU.Rank, PHD.HistoryDate DESC;
