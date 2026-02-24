WITH PostStatistics AS (
    SELECT 
        P.PostTypeId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.Score IS NOT NULL THEN P.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN P.ViewCount IS NOT NULL THEN P.ViewCount ELSE 0 END) AS TotalViews,
        AVG(P.ViewCount) AS AvgViewsPerPost,
        AVG(P.Score) AS AvgScorePerPost,
        MAX(P.CreationDate) AS MostRecentPost,
        MIN(P.CreationDate) AS OldestPost
    FROM 
        Posts P
    GROUP BY 
        P.PostTypeId
),
UserStatistics AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes,
        SUM(U.Views) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
)

SELECT 
    PST.PostTypeId,
    PST.PostCount,
    PST.TotalScore,
    PST.TotalViews,
    PST.AvgViewsPerPost,
    PST.AvgScorePerPost,
    PST.MostRecentPost,
    PST.OldestPost,
    UST.Id AS UserId,
    UST.DisplayName,
    UST.BadgeCount,
    UST.TotalUpVotes,
    UST.TotalDownVotes,
    UST.TotalViews
FROM 
    PostStatistics PST
CROSS JOIN 
    UserStatistics UST
ORDER BY 
    PST.PostTypeId, UST.DisplayName;