WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.ViewCount ELSE 0 END) AS QuestionViews,
        SUM(CASE WHEN P.PostTypeId = 2 THEN P.ViewCount ELSE 0 END) AS AnswerViews
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        BadgeCount,
        (UpVotes - DownVotes) AS NetVotes,
        (QuestionViews + AnswerViews) AS TotalViews
    FROM 
        UserStats
    WHERE 
        Reputation > 1000
    ORDER BY 
        TotalViews DESC, NetVotes DESC, Reputation DESC
    LIMIT 10
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.BadgeCount,
    U.NetVotes,
    U.TotalViews,
    ARRAY_AGG(DISTINCT P.Title) AS TopPosts,
    ARRAY_AGG(DISTINCT T.TagName) AS AssociatedTags
FROM 
    TopUsers U
LEFT JOIN 
    Posts P ON U.UserId = P.OwnerUserId
LEFT JOIN 
    Tags T ON P.Tags LIKE '%' || T.TagName || '%'
GROUP BY 
    U.UserId, U.DisplayName, U.Reputation, U.BadgeCount, U.NetVotes, U.TotalViews
ORDER BY 
    U.TotalViews DESC, U.NetVotes DESC;
