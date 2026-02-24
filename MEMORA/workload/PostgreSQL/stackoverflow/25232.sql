
WITH UserPostAnalytics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        MAX(u.Reputation) AS MaxReputation,
        STRING_AGG(t.TagName, ', ') AS PopularTags
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, '><')) AS t(TagName) ON TRUE
    WHERE 
        u.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        COUNT(ph.Id) AS EditCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 1 ELSE 0 END) AS ContentEditCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title
),
FinalResults AS (
    SELECT 
        up.DisplayName,
        up.PostCount,
        up.BadgeCount,
        up.QuestionCount,
        up.AnswerCount,
        up.PositivePosts,
        up.NegativePosts,
        up.MaxReputation,
        ph.Title,
        ph.EditCount,
        ph.ContentEditCount,
        ph.CloseCount,
        ROW_NUMBER() OVER (ORDER BY up.MaxReputation DESC) AS Ranking
    FROM 
        UserPostAnalytics up
    JOIN 
        PostHistoryStats ph ON up.UserId = ph.PostId
)

SELECT 
    Ranking,
    DisplayName,
    PostCount,
    BadgeCount,
    QuestionCount,
    AnswerCount,
    PositivePosts,
    NegativePosts,
    MaxReputation,
    Title,
    EditCount,
    ContentEditCount,
    CloseCount
FROM 
    FinalResults
ORDER BY 
    Ranking, MaxReputation DESC;
