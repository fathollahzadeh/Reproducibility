
WITH TagsSplit AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag
    FROM 
        Posts p
), 
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Author,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        STRING_AGG(DISTINCT ts.Tag, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        TagsSplit ts ON p.Id = ts.PostId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.ViewCount, p.Score
), 
ScoreSummary AS (
    SELECT 
        pd.Author,
        SUM(pd.Score) AS TotalScore,
        AVG(pd.ViewCount) AS AverageViews,
        COUNT(pd.PostId) AS PostCount
    FROM 
        PostDetails pd
    GROUP BY 
        pd.Author
), 
HighScorers AS (
    SELECT 
        ss.Author,
        ss.TotalScore,
        ss.AverageViews,
        ss.PostCount,
        ROW_NUMBER() OVER (ORDER BY ss.TotalScore DESC) AS Rank
    FROM 
        ScoreSummary ss
    WHERE 
        ss.TotalScore > 50 
)

SELECT 
    hs.Rank, 
    hs.Author, 
    hs.TotalScore, 
    hs.AverageViews, 
    hs.PostCount,
    (SELECT COUNT(DISTINCT(ts.Tag)) 
     FROM TagsSplit ts 
     WHERE ts.PostId IN (SELECT pd.PostId FROM PostDetails pd WHERE pd.Author = hs.Author)) AS DistinctTagCount
FROM 
    HighScorers hs
ORDER BY 
    hs.Rank;
