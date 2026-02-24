WITH TagCounts AS (
    SELECT
        Tags.TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedPostCount
    FROM 
        Posts P
    JOIN 
        Tags ON P.Tags LIKE '%' || Tags.TagName || '%'
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        Tags.TagName
), 
UserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COALESCE(PC.PostCount, 0) AS TotalPosts,
        COALESCE(UC.UpVoteCount, 0) AS TotalUpVotes,
        COALESCE(UC.DownVoteCount, 0) AS TotalDownVotes,
        COALESCE(TC.ClosedPostCount, 0) AS TotalClosedPosts
    FROM 
        Posts P
    LEFT JOIN 
        (SELECT 
            P.Id, 
            COUNT(P.Id) AS PostCount 
        FROM 
            Posts P 
        WHERE 
            P.PostTypeId IN (1, 2) 
        GROUP BY 
            P.Id) PC ON P.Id = PC.Id
    LEFT JOIN 
        UserVotes UC ON P.OwnerUserId = UC.UserId
    LEFT JOIN 
        TagCounts TC ON P.Tags LIKE '%' || TC.TagName || '%'
)
SELECT 
    Title,
    TotalPosts,
    TotalUpVotes,
    TotalDownVotes,
    TotalClosedPosts
FROM 
    PostMetrics
WHERE 
    TotalPosts > 1
ORDER BY 
    TotalPosts DESC, TotalUpVotes DESC, TotalDownVotes ASC
LIMIT 10;
